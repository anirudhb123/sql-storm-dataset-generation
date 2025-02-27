WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        Views,
        UpVotes,
        DownVotes,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown Reputation' 
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationCategory
    FROM Users
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and Downvotes
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    ) t ON true
    GROUP BY p.Id
), 
PopularPosts AS (
    SELECT 
        pd.*, 
        ROW_NUMBER() OVER (PARTITION BY pd.ReputationCategory ORDER BY pd.Score DESC) AS Rank
    FROM PostDetails pd
    JOIN UserReputation ur ON pd.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = ur.UserId)
    WHERE pd.ViewCount > 100 -- Considering only popular posts
), 
ClosedPosts AS (
    SELECT 
        PostId, 
        LastClosedDate, 
        CASE 
            WHEN LastClosedDate IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS IsClosed
    FROM PostDetails
)

SELECT 
    ur.DisplayName,
    pp.ReputationCategory,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.Tags,
    cp.IsClosed,
    COALESCE(cp.LastClosedDate, 'Never Closed') AS LastClosedDateFormatted,
    CASE 
        WHEN pp.Rank <= 3 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PopularityCategory
FROM PopularPosts pp
JOIN UserReputation ur ON pp.UserId = ur.UserId
LEFT JOIN ClosedPosts cp ON pp.PostId = cp.PostId
WHERE 
    (pp.ReputationCategory = 'Expert' OR pp.Rank <= 5) 
    AND cp.IsClosed = 'No'
    AND pp.ViewCount / NULLIF(pp.AnswerCount, 0) > 10 -- View to Answer Ratio
ORDER BY pp.Score DESC, pp.ViewCount DESC;
