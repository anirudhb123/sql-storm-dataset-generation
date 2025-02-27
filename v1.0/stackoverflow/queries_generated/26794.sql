WITH TagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(CASE WHEN LENGTH(t.TagName) > 10 THEN 1 ELSE 0 END) AS LongTagCount
    FROM 
        Posts p
    JOIN 
        UNNEST(SPLIT(Tags, '><')) AS t(TagName) ON p.Id = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS ActivePostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose votes
    WHERE 
        u.Reputation >= 100  -- Only consider users with reputation >= 100
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Title,
        p.Score,
        p.ViewCount,
        pc.UniqueTagCount,
        pc.LongTagCount,
        u.DisplayName AS OwnerDisplayName,
        au.ActivePostCount,
        au.TotalBounty
    FROM 
        Posts p
    JOIN 
        TagCounts pc ON p.Id = pc.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        ActiveUsers au ON u.Id = au.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  -- Only consider posts from the last year
),
RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    *,
    CONCAT(OwnerDisplayName, ' (Tags: ', LongTagCount, ' long tags, ', UniqueTagCount, ' unique tags)') AS PostInfo
FROM 
    RankedPosts
WHERE 
    Rank <= 50;  -- Get the top 50 ranked posts
