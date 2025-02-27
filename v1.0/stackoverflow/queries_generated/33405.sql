WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.CreationDate, u.LastAccessDate
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING(tags.value, 1, 35)) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') tags
    WHERE 
        tags.value IS NOT NULL AND tags.value <> ''
    GROUP BY 
        TRIM(SUBSTRING(tags.value, 1, 35))
    HAVING 
        COUNT(p.Id) > 10
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        ur.DisplayName,
        ur.Reputation,
        pt.TagName,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        (SELECT DISTINCT 
            PostId,
            t.TagName
        FROM 
            Posts p
        CROSS APPLY STRING_SPLIT(Tags, ',') t) pt ON rp.PostId = pt.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.DisplayName,
    tp.Reputation,
    STRING_AGG(tp.TagName, ', ') AS Tags
FROM 
    TopPosts tp
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.DisplayName, tp.Reputation
HAVING 
    MAX(tp.Reputation) >= 1000
ORDER BY 
    tp.Score DESC
OPTION (MAXRECURSION 0);
