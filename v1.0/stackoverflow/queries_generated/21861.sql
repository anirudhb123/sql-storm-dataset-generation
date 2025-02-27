WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        ROW_NUMBER() OVER (PARTITION BY u.AccountId ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        pt.Name AS PostType,
        COUNT(v.Id) AS VoteCount,
        array_agg(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tagname ON tagname IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tagname
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
    HAVING 
        COUNT(v.Id) > 10
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ctr.Name AS Reason,
        COUNT(*) AS ReasonCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::INT = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ctr.Name
),
PostRankings AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.VoteCount,
        COALESCE(cr.Reason, 'Not Closed') AS CloseReason,
        DENSE_RANK() OVER (ORDER BY pp.Score DESC) AS PostRank
    FROM 
        PopularPosts pp
    LEFT JOIN 
        CloseReasons cr ON pp.PostId = cr.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    pr.Title,
    pr.Score,
    pr.VoteCount,
    pr.CloseReason
FROM 
    UserReputation u
JOIN 
    PostRankings pr ON pr.PostRank <= 3
WHERE 
    u.Rank = 1
ORDER BY 
    u.Reputation DESC, pr.Score DESC
LIMIT 10;

This query performs the following functions:

1. **UserReputation CTE**: Filters users with high reputation and ranks them by their reputation within their account group.
2. **PopularPosts CTE**: Identifies posts created in the last year that are highly voted, aggregating their tags into an array.
3. **CloseReasons CTE**: Counts the different reasons posts are closed, linking to the `CloseReasonTypes`.
4. **PostRankings CTE**: Ranks popular posts based on their score, while also including any close reasons.
5. The final selection retrieves the top-ranked users with the highest reputation, along with their top three ranked posts, their scores, vote counts, and any close reasons, ordered accordingly.

This example utilizes several advanced SQL features such as CTEs, window functions, aggregation, and more to provide a comprehensive performance benchmark query suitable for analysis.
