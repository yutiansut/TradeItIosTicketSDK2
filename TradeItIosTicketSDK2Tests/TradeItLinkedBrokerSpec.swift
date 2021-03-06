import Quick
import Nimble
@testable import TradeItIosTicketSDK2

class TradeItLinkedBrokerSpec: QuickSpec {
    override func spec() {
        var linkedBroker: TradeItLinkedBroker!
        var session: FakeTradeItSession!
        var linkedLogin: TradeItLinkedLogin!

        beforeEach {
            session = FakeTradeItSession()
            linkedLogin = TradeItLinkedLogin(label: "My Special Label",
                broker: "My Special Broker",
                userId: "My Special User ID",
                keyChainId: "My Special Keychain ID"
            )

            linkedBroker = TradeItLinkedBroker(session: session, linkedLogin: linkedLogin)
        }

        describe("initialization") {
            it("initializes linkedBroker as not authenticated") {
                expect(linkedBroker.error).notTo(beNil())
            }

            it("sets the session") {
                expect(linkedBroker.session).to(be(session))
            }

            it("sets the linkedLogin") {
                expect(linkedBroker.linkedLogin).to(be(linkedLogin))
            }
        }

        describe("authenticate") {
            var onSuccessWasCalled = false
            var onFailureWasCalled = false
            var onSecurityQuestionWasCalled = false
            beforeEach {
                onSuccessWasCalled = false
                onFailureWasCalled = false
                onSecurityQuestionWasCalled = false
                
                linkedBroker.authenticate(
                    onSuccess: {
                        onSuccessWasCalled = true
                    },
                    onSecurityQuestion: { (tradeItSecurityQuestionResult: TradeItSecurityQuestionResult, onSecurityQuestionAnswered: (String) -> Void,  onCancelSecurityQuestion: () -> Void) -> Void in
                        onSecurityQuestionWasCalled = true
                    },
                    onFailure: {(tradeItErrorResult: TradeItErrorResult) -> Void in
                        onFailureWasCalled = true
                    }
                )
            }

            xcontext("when authentication succeeds") {
                var returnedAccounts: [TradeItBrokerAccount] = []

                beforeEach {
                    let account1 = TradeItBrokerAccount(accountBaseCurrency: "My base currency", accountNumber: "My account number 1", name: "My account name 1", tradable: true)!
                    let account2 =  TradeItBrokerAccount(accountBaseCurrency: "My base currency", accountNumber: "My account number 2", name: "My account name 2", tradable: true)!

                    returnedAccounts = [account1, account2]

                    let completionBlock = session.calls.forMethod("authenticate(_:withCompletionBlock:)")[0].args["withCompletionBlock"] as! ((TradeItResult!) -> Void)
                    let tradeItAuthenticationResult = TradeItAuthenticationResult()
                    tradeItAuthenticationResult.accounts = returnedAccounts

                    completionBlock(tradeItAuthenticationResult)
                }

                it("updates wasAuthenticated to be true") {
                    expect(linkedBroker.error).to(beNil())
                }

                it("populates accounts from the authentication response") {
                    expect(linkedBroker.accounts.count).to(equal(2))

                    var account = linkedBroker.accounts[0]
                    expect(account.accountName).to(equal("My account name 1"))
                    expect(account.accountNumber).to(equal("My account number 1"))
                    expect(account.brokerName).to(equal("My Special Broker"))
                    expect(account.balance).to(beNil())
                    expect(account.fxBalance).to(beNil())
                    expect(account.positions).to(beEmpty())


                    account = linkedBroker.accounts[1]
                    expect(account.accountName).to(equal("My account name 2"))
                    expect(account.accountNumber).to(equal("My account number 2"))
                    expect(account.brokerName).to(equal("My Special Broker"))
                    expect(account.balance).to(beNil())
                    expect(account.fxBalance).to(beNil())
                    expect(account.positions).to(beEmpty())
                }
                
                it("sets the error variable to nil") {
                    expect(linkedBroker.error).to(beNil())
                }

                it("calls onSuccess") {
                    expect(onSuccessWasCalled).to(beTrue())
                    expect(onFailureWasCalled).to(beFalse())
                    expect(onSecurityQuestionWasCalled).to(beFalse())
                }
            }

            xcontext("when there is a security question") {
                var tradeItSecurityQuestionResult: TradeItSecurityQuestionResult!
                beforeEach {
                    tradeItSecurityQuestionResult = TradeItSecurityQuestionResult()
                    let completionBlock = session.calls.forMethod("authenticate(_:withCompletionBlock:)")[0].args["withCompletionBlock"] as! ((TradeItResult!) -> Void)
                    completionBlock(tradeItSecurityQuestionResult)
                }
                
                it("calls onSecurityQuestion") {
                    expect(onSuccessWasCalled).to(beFalse())
                    expect(onFailureWasCalled).to(beFalse())
                    expect(onSecurityQuestionWasCalled).to(beTrue())
                }
                
                //TODO to complete
            }

            xcontext("when authentication fails") {
                var tradeItErrorResult: TradeItErrorResult!
                beforeEach {
                    tradeItErrorResult = TradeItErrorResult()
                    let completionBlock = session.calls.forMethod("authenticate(_:withCompletionBlock:)")[0].args["withCompletionBlock"] as! ((TradeItResult!) -> Void)
                    completionBlock(tradeItErrorResult)
                }
                
                it("updates wasAuthenticated to be false") {
                    expect(linkedBroker.error).notTo(beNil())
                }
                
                it("keeps a reference to the error") {
                    expect(linkedBroker.error).to(be(tradeItErrorResult))
                }

                it("calls onFailure") {
                    expect(onSuccessWasCalled).to(beFalse())
                    expect(onFailureWasCalled).to(beTrue())
                    expect(onSecurityQuestionWasCalled).to(beFalse())
                }
            }
        }

        describe("refreshAccountBalances") {
            var account11: FakeTradeItLinkedBrokerAccount!
            var account12: FakeTradeItLinkedBrokerAccount!
            var onfinishedWasCalled = false
            beforeEach {
                onfinishedWasCalled = false
                account11 = FakeTradeItLinkedBrokerAccount(linkedBroker: linkedBroker, accountName: "My account #11", accountNumber: "123456789", balance: nil, fxBalance: nil, positions: [])
                account12 = FakeTradeItLinkedBrokerAccount(linkedBroker: linkedBroker, accountName: "My account #12", accountNumber: "234567890", balance: nil, fxBalance: nil, positions: [])
                linkedBroker.accounts = [account11, account12]
                
                linkedBroker.refreshAccountBalances(onFinished: {
                    onfinishedWasCalled = true
                })
                
            }
            
            it("calls getAccountsOverview for each account") {
                expect(account11.calls.forMethod("getAccountOverview(onSuccess:onFailure:)").count).to(equal(1))
                expect(account12.calls.forMethod("getAccountOverview(onSuccess:onFailure:)").count).to(equal(1))
            }
            
            context("when all the accounts balances have been fetched") {
                beforeEach {
                        let onSuccess = account11.calls.forMethod("getAccountOverview(onSuccess:onFailure:)")[0].args["onSuccess"] as! (TradeItAccountOverview?) -> Void
                        onSuccess(TradeItAccountOverview())
                        let onFailure = account12.calls.forMethod("getAccountOverview(onSuccess:onFailure:)")[0].args["onFailure"] as! (TradeItErrorResult) -> Void
                        onFailure(TradeItErrorResult())
                        flushAsyncEvents()
                }
                
                it("calls onFinished") {
                    expect(onfinishedWasCalled).to(beTrue())
                }
                it("the error is present on the linkedBroker because of the second balance call failure") {
                    expect(linkedBroker.error).notTo(beNil())
                }
            }
        }
    }
}
