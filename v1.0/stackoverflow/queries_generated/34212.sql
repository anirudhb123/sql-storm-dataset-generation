WITH RecursiveTagCounts AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.Id = p.AcceptedAnswerId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '6 months'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, a.AcceptedAnswerId
),
PopularPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        rt.TagId,
        rt.TagName,
        ROW_NUMBER() OVER (PARTITION BY rt.TagId ORDER BY ps.Score DESC) AS PopularityRank
    FROM 
        PostStatistics ps
    INNER JOIN 
        RecursiveTagCounts rt ON ps.Title LIKE '%' || rt.TagName || '%'
)
SELECT 
    up.DisplayName AS UserDisplayName,
    pp.Title AS PopularPostTitle,
    pp.ViewCount,
    pp.Score AS PostScore,
    rt.TagName AS AssociatedTag,
    pp.PopularityRank
FROM 
    PopularPosts pp
JOIN 
    UserReputation up ON pp.ViewCount >= 1000 AND up.Reputation > 500
WHERE 
    pp.PopularityRank <= 5
ORDER BY 
    pp.TagId, pp.PopularityRank;
