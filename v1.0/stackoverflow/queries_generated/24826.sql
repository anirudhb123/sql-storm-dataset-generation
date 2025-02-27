WITH UserReputation AS (
    SELECT
        Id,
        Reputation,
        CASE
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation BETWEEN 500 AND 999 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        U.ReputationLevel,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    JOIN UserReputation U ON p.OwnerUserId = U.Id
    WHERE p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS Upvotes, -- UpMod (Upvotes)
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS Downvotes -- DownMod (Downvotes)
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Only Questions
    GROUP BY p.Id
),
UserPostsCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UP.PostId,
        UP.CommentCount,
        UP.Upvotes,
        UP.Downvotes,
        CASE
            WHEN UP.Upvotes > UP.Downvotes THEN 'Positive'
            WHEN UP.Upvotes < UP.Downvotes THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM Users U
    JOIN RecentActivePosts RAP ON U.Id = RAP.OwnerUserId
    JOIN PostDetails UP ON RAP.PostId = UP.PostId
    WHERE RAP.rn = 1
)
SELECT 
    U.DisplayName,
    U.ReputationLevel,
    UP.PostId,
    UP.CommentCount,
    UP.Upvotes,
    UP.Downvotes,
    UP.PostSentiment,
    CASE 
        WHEN UP.CommentCount IS NULL THEN 'No Comments' 
        ELSE 'Has Comments'
    END AS Comment_Status,
    STRING_AGG(DISTINCT CONCAT('Tag: ', SUBSTRING(p.Tags FROM 1 FOR 30)), ', ') AS TagsList
FROM UserPostsCTE UP
JOIN Posts p ON UP.PostId = p.Id
LEFT JOIN PostsTags pt ON p.Id = pt.PostId -- Assuming a hypothetical PostsTags for illustration
WHERE (UP.Upvotes - UP.Downvotes) BETWEEN 1 AND 10
GROUP BY 
    U.DisplayName, 
    U.ReputationLevel, 
    UP.PostId, 
    UP.CommentCount, 
    UP.Upvotes, 
    UP.Downvotes, 
    UP.PostSentiment
ORDER BY U.ReputationLevel DESC, UP.Upvotes DESC NULLS LAST;

### Explanation:
- **Common Table Expressions (CTEs)**: Utilizes several CTEs to streamline data processing. `UserReputation` categorizes user reputation, `RecentActivePosts` gathers relevant posts from the last 30 days, and `PostDetails` collates comment counts and vote tallies.
- **Window Functions**: Implements `ROW_NUMBER()` to identify the most recent post per user.
- **NULL Logic**: Includes `COALESCE` to handle potential NULLs in vote counts.
- **Strings and Aggregations**: Uses `STRING_AGG` to create a concatenated list of tags while handling the intricacies of string substitutions.
- **Complicated Predicates**: Returns users’ posts based on a nuanced understanding of their engagement metrics (e.g., total votes gained).
- **Outer Joins**: Leverages LEFT JOINs to preserve user context even when comments/votes may not exist. 
