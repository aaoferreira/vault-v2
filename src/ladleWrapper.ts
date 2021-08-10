import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'
import { ethers, BigNumberish, ContractTransaction, BytesLike, PayableOverrides } from 'ethers'
import { Ladle } from '../typechain/Ladle'

export class LadleWrapper {
  ladle: Ladle
  address: string

  pool = new ethers.utils.Interface([
    "function sellBase(address to, uint128 min)",
    "function sellFYToken(address to, uint128 min)",
    "function mint(address to, bool, uint256 minTokensMinted)",
    "function mintWithBase(address to, uint256 fyTokenToBuy, uint256 minTokensMinted)",
    "function burnForBase(address to, uint256 minBaseOut)",
    "function burn(address to, uint256 minBaseOut, uint256 minFYTokenOut)",
  ]);

  tlmModule = new ethers.utils.Interface([
    "function approve(bytes6 seriesId)",
    "function sell(bytes6 seriesId, address to, uint256 fyDaiToSell)",
  ]);

  constructor(ladle: Ladle) {
    this.ladle = ladle
    this.address = ladle.address
  }

  public static async setup(ladle: Ladle) {
    return new LadleWrapper(ladle)
  }

  public connect(account: SignerWithAddress): LadleWrapper {
    return new LadleWrapper(this.ladle.connect(account))
  }

  public async setFee(fee: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.setFee(fee)
  }

  public async borrowingFee(): Promise<BigNumberish> {
    return this.ladle.borrowingFee()
  }

  public async addJoin(assetId: string, join: string): Promise<ContractTransaction> {
    return this.ladle.addJoin(assetId, join)
  }

  public async addPool(assetId: string, pool: string): Promise<ContractTransaction> {
    return this.ladle.addPool(assetId, pool)
  }

  public async setModule(module: string, set: boolean): Promise<ContractTransaction> {
    return this.ladle.setModule(module, set)
  }

  public async grantRoles(roles: Array<string>, user: string): Promise<ContractTransaction> {
    return this.ladle.grantRoles(roles, user)
  }

  public async joins(ilkId: string): Promise<string> {
    return this.ladle.joins(ilkId)
  }

  public async pools(seriesId: string): Promise<string> {
    return this.ladle.pools(seriesId)
  }

  public async batch(actions: Array<string>, overrides?: PayableOverrides): Promise<ContractTransaction> {
    if (overrides === undefined) return this.ladle.batch(actions)
    else return this.ladle.batch(actions, overrides)
  }

  public buildAction(seriesId: string, ilkId: string): string {
    return this.ladle.interface.encodeFunctionData('build', [seriesId, ilkId, 0])
  }

  public async build(seriesId: string, ilkId: string): Promise<ContractTransaction> {
    return this.ladle.build(seriesId, ilkId, 0)
  }

  public tweakAction(vaultId: string, seriesId: string, ilkId: string): string {
    return this.ladle.interface.encodeFunctionData('tweak', [vaultId, seriesId, ilkId])
  }

  public async tweak(vaultId: string, seriesId: string, ilkId: string): Promise<ContractTransaction> {
    return this.ladle.tweak(vaultId, seriesId, ilkId)
  }

  public giveAction(vaultId: string, to: string): string {
    return this.ladle.interface.encodeFunctionData('give', [vaultId, to])
  }

  public async give(vaultId: string, to: string): Promise<ContractTransaction> {
    return this.ladle.give(vaultId, to)
  }

  public destroyAction(vaultId: string): string {
    return this.ladle.interface.encodeFunctionData('destroy', [vaultId])
  }

  public async destroy(vaultId: string): Promise<ContractTransaction> {
    return this.ladle.destroy(vaultId)
  }

  public stirAction(from: string, to: string, ink: BigNumberish, art: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('stir', [from, to, ink, art])
  }

  public async stir(from: string, to: string, ink: BigNumberish, art: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.stir(from, to, ink, art)
  }

  public pourAction(vaultId: string, to: string, ink: BigNumberish, art: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('pour', [vaultId, to, ink, art])
  }

  public async pour(vaultId: string, to: string, ink: BigNumberish, art: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.pour(vaultId, to, ink, art)
  }

  public closeAction(vaultId: string, to: string, ink: BigNumberish, art: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('close', [vaultId, to, ink, art])
  }

  public async close(vaultId: string, to: string, ink: BigNumberish, art: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.close(vaultId, to, ink, art)
  }

  public serveAction(vaultId: string, to: string, ink: BigNumberish, base: BigNumberish, max: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('serve', [vaultId, to, ink, base, max])
  }

  public async serve(vaultId: string, to: string, ink: BigNumberish, base: BigNumberish, max: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.serve(vaultId, to, ink, base, max)
  }

  public repayAction(vaultId: string, to: string, ink: BigNumberish, min: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('repay', [vaultId, to, ink, min])
  }

  public async repay(vaultId: string, to: string, ink: BigNumberish, min: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.repay(vaultId, to, ink, min)
  }

  public repayVaultAction(vaultId: string, to: string, ink: BigNumberish, max: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('repayVault', [vaultId, to, ink, max])
  }

  public async repayVault(vaultId: string, to: string, ink: BigNumberish, max: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.repayVault(vaultId, to, ink, max)
  }

  public repayLadleAction(vaultId: string): string {
    return this.ladle.interface.encodeFunctionData('repayLadle', [vaultId])
  }

  public async repayLadle(vaultId: string): Promise<ContractTransaction> {
    return this.ladle.repayLadle(vaultId)
  }

  public retrieveAction(assetId: string, isAsset: boolean, to: string): string {
    return this.ladle.interface.encodeFunctionData('retrieve', [assetId, isAsset, to])
  }

  public async retrieve(assetId: string, isAsset: boolean, to: string): Promise<ContractTransaction> {
    return this.ladle.retrieve(assetId, isAsset, to)
  }

  public rollAction(vaultId: string, newSeriesId: string, loan: BigNumberish, max: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('roll', [vaultId, newSeriesId, loan, max])
  }

  public async roll(vaultId: string, newSeriesId: string, loan: BigNumberish, max: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.roll(vaultId, newSeriesId, loan, max)
  }

  public forwardPermitAction(id: string, isAsset: boolean, spender: string, amount: BigNumberish, deadline: BigNumberish, v: BigNumberish, r: Buffer, s: Buffer): string {
    return this.ladle.interface.encodeFunctionData('forwardPermit',
      [id, isAsset, spender, amount, deadline, v, r, s]
    )
  }

  public async forwardPermit(id: string, isAsset: boolean, spender: string, amount: BigNumberish, deadline: BigNumberish, v: BigNumberish, r: Buffer, s: Buffer): Promise<ContractTransaction> {
    return this.ladle.forwardPermit(id, isAsset, spender, amount, deadline, v, r, s)
  }

  public forwardDaiPermitAction(id: string, isAsset: boolean, spender: string, nonce: BigNumberish, deadline: BigNumberish, approved: boolean, v: BigNumberish, r: Buffer, s: Buffer): string {
    return this.ladle.interface.encodeFunctionData('forwardDaiPermit',
      [id, isAsset, spender, nonce, deadline, approved, v, r, s]
    )
  }

  public async forwardDaiPermit(id: string, isAsset: boolean, spender: string, nonce: BigNumberish, deadline: BigNumberish, approved: boolean, v: BigNumberish, r: Buffer, s: Buffer): Promise<ContractTransaction> {
    return this.ladle.forwardDaiPermit(id, isAsset, spender, nonce, deadline, approved, v, r, s)
  }

  public joinEtherAction(etherId: string): string {
    return this.ladle.interface.encodeFunctionData('joinEther', [etherId])
  }

  public async joinEther(etherId: string, overrides?: any): Promise<ContractTransaction> {
    return this.ladle.joinEther(etherId, overrides)
  }

  public exitEtherAction(to: string): string {
    return this.ladle.interface.encodeFunctionData('exitEther', [to])
  }

  public async exitEther(to: string): Promise<ContractTransaction> {
    return this.ladle.exitEther(to)
  }

  public transferToPoolAction(seriesId: string, base: boolean, wad: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('transferToPool', [seriesId, base, wad])
  }

  public async transferToPool(seriesId: string, base: boolean, wad: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.transferToPool(seriesId, base, wad)
  }

  public routeAction(seriesId: string, poolCall: string): string {
    return this.ladle.interface.encodeFunctionData('route', [seriesId, poolCall])
  }

  public async route(seriesId: string, poolCall: string): Promise<ContractTransaction> {
    return this.ladle.route(seriesId, poolCall)
  }

  public transferToFYTokenAction(seriesId: string, wad: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('transferToFYToken', [seriesId, wad])
  }

  public async transferToFYToken(seriesId: string, wad: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.transferToFYToken(seriesId, wad)
  }

  public redeemAction(seriesId: string, to: string, wad: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('redeem', [seriesId, to, wad])
  }

  public async redeem(seriesId: string, to: string, wad: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.redeem(seriesId, to, wad)
  }

  public sellBaseAction(seriesId: string, receiver: string, min: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('route',
      [
        seriesId,
        this.pool.encodeFunctionData('sellBase', [receiver, min])
      ]
    )
  }

  public async sellBase(seriesId: string, receiver: string, min: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.route(seriesId, this.pool.encodeFunctionData('sellBase', [receiver, min]))
  }

  public sellFYTokenAction(seriesId: string, receiver: string, min: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('route',
      [
        seriesId,
        this.pool.encodeFunctionData('sellFYToken', [receiver, min])
      ]
    )
  }

  public async sellFYToken(seriesId: string, receiver: string, min: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.route(seriesId, this.pool.encodeFunctionData('sellFYToken', [receiver, min]))
  }

  public mintWithBaseAction(seriesId: string, receiver: string, fyTokenToBuy: BigNumberish, minTokensMinted: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('route',
      [
        seriesId,
        this.pool.encodeFunctionData('mintWithBase', [receiver, fyTokenToBuy, minTokensMinted])
      ]
    )
  }

  public async mintWithBase(seriesId: string, receiver: string, fyTokenToBuy: BigNumberish, minTokensMinted: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.route(seriesId, this.pool.encodeFunctionData('mintWithBase', [receiver, fyTokenToBuy, minTokensMinted]))
  }

  public burnForBaseAction(seriesId: string, receiver: string, minBaseOut: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('route',
      [
        seriesId,
        this.pool.encodeFunctionData('burnForBase', [receiver, minBaseOut])
      ]
    )
  }

  public async burnForBase(seriesId: string, receiver: string, minBaseOut: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.route(seriesId, this.pool.encodeFunctionData('burnForBase', [receiver, minBaseOut]))
  }

  public tlmApproveAction(tlmModuleAddress: string, seriesId: string): string {
    const tlmApproveCall = this.tlmModule.encodeFunctionData('approve', [seriesId])

    return this.ladle.interface.encodeFunctionData('moduleCall',
      [tlmModuleAddress, tlmApproveCall]
    )
  }

  public async tlmApprove(tlmModuleAddress: string, seriesId: string): Promise<ContractTransaction> {
    const tlmApproveCall = this.tlmModule.encodeFunctionData('approve', [seriesId])
    return this.ladle.moduleCall(tlmModuleAddress, tlmApproveCall)
  }

  public tlmSellAction(tlmModuleAddress: string, seriesId: string, receiver: string, amount: BigNumberish): string {
    const tlmSellCall = this.tlmModule.encodeFunctionData('sell', [seriesId, receiver, amount])
    return this.ladle.interface.encodeFunctionData('moduleCall',
      [tlmModuleAddress, tlmSellCall]
    )
  }

  public async tlmSell(tlmModuleAddress: string, seriesId: string, receiver: string, amount: BigNumberish): Promise<ContractTransaction> {
    const tlmSellCall = this.tlmModule.encodeFunctionData('sell', [seriesId, receiver, amount])
    return this.ladle.tlmSell(tlmModuleAddress, tlmSellCall)
  }

  public transferToModuleAction(assetId: string, module_: string, wad: BigNumberish): string {
    return this.ladle.interface.encodeFunctionData('transferToModule', [assetId, module_, wad])
  }

  public async transferToModule(assetId: string, module_: string, wad: BigNumberish): Promise<ContractTransaction> {
    return this.ladle.transferToModule(assetId, module_, wad)
  }
}
  