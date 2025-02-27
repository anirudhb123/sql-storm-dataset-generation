WITH UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedVotes
    FROM Votes v
    JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY v.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.Score,
        COALESCE(CAST(votes.UpVotes AS INT), 0) AS TotalUpVotes,
        COALESCE(CAST(votes.DownVotes AS INT), 0) AS TotalDownVotes,
        COALESCE(CAST(votes.AcceptedVotes AS INT), 0) AS TotalAcceptedVotes,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN UserVotes votes ON p.OwnerUserId = votes.UserId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
      AND p.Score IS NOT NULL
      AND (p.ViewCount > 100 OR p.Score > 10)
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (PARTITION BY pd.OwnerUserId ORDER BY pd.Score DESC) AS Rank
    FROM PostDetails pd
)
SELECT 
    up.OwnerDisplayName,
    rp.PostId,
    rp.Score,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        WHEN rp.PostTypeId IN (4, 5) THEN 'Wiki'
        ELSE 'Other'
    END AS PostType,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasAcceptedAnswer
FROM RankedPosts rp
JOIN Users up ON up.Id = rp.OwnerUserId
WHERE rp.Rank <= 5
  AND (up.Reputation > 1000 OR up.Views > 10000)
ORDER BY rp.Score DESC, rp.CommentCount DESC;
