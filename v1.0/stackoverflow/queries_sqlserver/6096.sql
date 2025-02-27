
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
      AND p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(ISNULL(b.Class, 0)) AS TotalBadges,
        SUM(ISNULL(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
AggregatedData AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalBadges,
        us.TotalBounty,
        rp.Title,
        rp.Score,
        rp.ViewCount
    FROM 
        UserStats us
    JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId
    WHERE 
        rp.RN <= 5
)
SELECT 
    ad.DisplayName,
    ad.QuestionCount,
    ad.TotalBadges,
    ad.TotalBounty,
    ad.Title,
    ad.Score,
    ad.ViewCount
FROM 
    AggregatedData ad
ORDER BY 
    ad.TotalBounty DESC, ad.QuestionCount DESC, ad.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
