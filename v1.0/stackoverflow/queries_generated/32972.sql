WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.ParentId = a.Id
    WHERE 
        a.PostTypeId = 1  -- Join with Answers based on the ParentId
),
UserReputationStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,  -- Count upvotes
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,  -- Count downvotes
        COUNT(DISTINCT p.Id) AS PostCount  -- Count total posts by user
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id
),
TaggedPostStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(
            CASE 
                WHEN COALESCE(p AnswerCount, 0) > 0 THEN CAST(p.Score AS FLOAT) / p.AnswerCount 
                ELSE NULL 
            END
        ) AS AverageScorePerAnswer
    FROM 
        Tags t
    JOIN 
        Posts p ON POSITION(t.TagName IN p.Tags) > 0  -- To get posts with the corresponding tags
    GROUP BY 
        t.TagName
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.UpVotes,
    u.DownVotes,
    CASE 
        WHEN u.UpVotes + u.DownVotes > 0 
        THEN CAST(u.UpVotes AS FLOAT) / (u.UpVotes + u.DownVotes) 
        ELSE NULL 
    END AS VoteRatio,
    tp.TagName,
    tp.PostCount AS TaggedPostCount,
    tp.TotalViews AS TaggedPostTotalViews,
    tp.AverageScorePerAnswer
FROM 
    UserReputationStats u
LEFT JOIN 
    TaggedPostStats tp ON u.PostCount > 0
WHERE 
    u.Reputation > 100  -- Filter users with a reputation greater than 100
ORDER BY 
    u.Reputation DESC, 
    tp.PostCount DESC
LIMIT 100;
This SQL query combines multiple advanced SQL constructs including Common Table Expressions (CTEs) with recursion, aggregation, correlated subqueries for derived metrics, and complex predicates. It gathers user statistics, post tagging information and combines everything to analyze user participation and post metrics effectively.
