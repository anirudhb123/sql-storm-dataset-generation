WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(substring(tags, 2, length(tags)-2), '>'))) ) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    p.Title AS TopPostTitle,
    p.Score AS TopPostScore,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ph.FirstCloseDate AS PostFirstClosedDate,
    t.TagName AS PopularTag,
    t.TagCount AS PopularTagCount
FROM 
    RankedPosts p
JOIN 
    TopUsers u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    ClosedPosts ph ON p.PostId = ph.PostId
CROSS JOIN 
    PopularTags t
WHERE 
    p.Rank = 1
    AND u.UpVotesCount > u.DownVotesCount
    AND ph.PostId IS not NULL
ORDER BY 
    p.Score DESC,
    u.Reputation DESC;
