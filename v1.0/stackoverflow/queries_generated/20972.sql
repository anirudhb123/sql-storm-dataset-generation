WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),

FrequentTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.TagName) AS TagCount
    FROM 
        Tags t
    JOIN 
        LATERAL STRING_TO_ARRAY(t.TagName, ',') AS pt(TagName)
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.TagName) > 5
),

UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBadgeScore,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  -- Bounty start and close
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    ft.TagName,
    us.DisplayName AS UserDisplayName,
    us.TotalBadgeScore,
    us.TotalBounty
FROM 
    RankedPosts rp
LEFT JOIN 
    FrequentTags ft ON rp.PostId IN (
        SELECT 
            p.Id
        FROM 
            Posts p
        WHERE 
            p.Tags LIKE '%' || ft.TagName || '%'
    )
JOIN 
    Users u ON u.Id = rp.PostId  -- Assuming Posts have OwnerUserId to get User
LEFT JOIN 
    UserScore us ON us.UserId = u.Id
WHERE 
    (rp.PostRank <= 5 OR ft.TagCount IS NOT NULL)  -- Only top 5 posts by type or those with frequent tags
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;

This query uses Common Table Expressions (CTEs) to first rank posts from the last year, calculate frequent tags, and evaluate user scores based on badges and bounties. It combines various constructs such as window functions, joins, and subqueries, while utilizing conditional aggregation and complex filtering criteria. This strategy assesses both post and user engagement effectively.
