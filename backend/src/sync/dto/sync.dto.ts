import { IsNotEmpty, IsString, IsOptional, IsArray } from 'class-validator';

export class SyncPushDto {
  @IsNotEmpty()
  @IsString()
  shopId: string;

  @IsOptional()
  @IsArray()
  categories?: any[];

  @IsOptional()
  @IsArray()
  products?: any[];

  @IsOptional()
  @IsArray()
  customers?: any[];

  @IsOptional()
  @IsArray()
  customerLedgers?: any[];

  @IsOptional()
  @IsArray()
  orders?: any[];

  @IsOptional()
  @IsArray()
  orderItems?: any[];
}
