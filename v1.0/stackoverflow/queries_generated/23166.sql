WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            WHEN u.Reputation = 0 THEN 'Neutral'
            WHEN u.Reputation > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS ReputationStatus,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),

PostWithUserData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),

TaggedPosts AS (
    SELECT 
        p.PostId,
        unnest(string_to_array(p.Tags, ',')) AS Tag,
        p.Title
    FROM PostWithUserData p
    WHERE p.Score > 10
),

PopularTags AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM TaggedPosts
    GROUP BY Tag
    HAVING COUNT(*) > 1
),

RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.UserId) AS VoteCount
    FROM Votes v
    WHERE v.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY v.PostId, v.VoteTypeId
),

FinalRanking AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        v.VoteCount,
        COALESCE(tag.PostCount, 0) AS TagUsage
    FROM PostWithUserData p
    LEFT JOIN RecentVotes v ON p.PostId = v.PostId
    LEFT JOIN PopularTags tag ON p.Title ILIKE '%' || tag.Tag || '%'
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.VoteCount,
    CASE 
        WHEN fr.TagUsage > 0 THEN 'Very Popular'
        WHEN fr.Score > 20 THEN 'Celeb Post'
        ELSE 'Regular Post'
    END AS PostType,
    RANK() OVER (ORDER BY COALESCE(fr.VoteCount, 0) DESC, fr.Score DESC) AS Rank
FROM FinalRanking fr
WHERE fr.ViewCount > 50 
ORDER BY Rank, fr.CreationDate DESC;

-- Bonus: To demonstrate knowledge of outer joins and weird behaviors
SELECT DISTINCT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COALESCE(
        (SELECT COUNT(DISTINCT b.Id) 
         FROM Badges b 
         WHERE b.UserId = u.Id AND b.Class = 1),
        0) AS GoldBadges
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
GROUP BY u.Id
HAVING COUNT(DISTINCT p.Id) > 0 OR COUNT(DISTINCT b.Id) > 0;
This SQL query encapsulates a variety of advanced SQL constructs while adhering to the provided schema. It includes Common Table Expressions (CTEs) for structuring subqueries, window functions for ranking, outer joins for linking users with their posts and badges, and even incorporates conditional logic for semantic analysis of post types and user reputations. Additionally, it represents various aggregate functions and handles NULL values appropriately, demonstrating some obscure SQL behaviors.
