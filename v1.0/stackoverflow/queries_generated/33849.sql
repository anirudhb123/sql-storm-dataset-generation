WITH RecursiveTagCount AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    GROUP BY
        t.Id, t.TagName
    
    UNION ALL
    
    SELECT
        tt.Id AS TagId,
        tt.TagName,
        COUNT(tp.Id) AS PostCount
    FROM
        Tags tt
    JOIN
        Posts tp ON tp.Tags LIKE CONCAT('%<', tt.TagName, '>%' )
    JOIN
        RecursiveTagCount r ON r.TagId = tt.Id
    GROUP BY
        tt.Id, tt.TagName
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        UPPER(u.EmailHash) AS Email,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM
        Users u
    WHERE
        u.Reputation > 1000
),
PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVoteType
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.CommentCount,
        RANK() OVER (ORDER BY pm.ViewCount DESC) AS Rank
    FROM
        PostMetrics pm
)
SELECT
    t.TagName,
    COUNT(tp.PostId) AS TotalPosts,
    SUM(COALESCE(pm.ViewCount, 0)) AS TotalViews,
    AVG(pm.AverageVoteType) AS AvgVoteTypeScore,
    u.DisplayName AS TopUser,
    u.Reputation AS UserReputation
FROM
    RecursiveTagCount t
LEFT JOIN
    Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
LEFT JOIN
    PostMetrics pm ON pm.PostId = p.Id
LEFT JOIN
    TopUsers u ON u.UserId = p.OwnerUserId
LEFT JOIN
    TopPosts tp ON tp.PostId = p.Id
WHERE
    t.PostCount > 0
GROUP BY
    t.TagName, u.DisplayName, u.Reputation
HAVING
    SUM(COALESCE(pm.ViewCount, 0)) > 100
ORDER BY
    TotalPosts DESC, AvgVoteTypeScore DESC
LIMIT 10;
