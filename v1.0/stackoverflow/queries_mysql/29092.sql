
WITH PostDetails AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.Tags,
           u.DisplayName AS OwnerDisplayName,
           p.CreationDate,
           ph.CreationDate AS LastEdited,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount,
           GROUP_CONCAT(DISTINCT t.TagName) AS TagNames
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN PostHistory ph ON ph.PostId = p.Id 
                               AND ph.PostHistoryTypeId IN (4, 5, 6)  
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    LEFT JOIN Tags t ON FIND_IN_SET(t.TagName, TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags))) > 0
    WHERE p.PostTypeId = 1  
    GROUP BY p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, ph.CreationDate
), 
RankedPosts AS (
    SELECT PostId,
           Title,
           OwnerDisplayName,
           CreationDate,
           LastEdited,
           CommentCount,
           VoteCount,
           @rank := IF(@prev_vote = VoteCount, @rank, @rank + 1) AS Rank,
           @prev_vote := VoteCount
    FROM PostDetails, (SELECT @rank := 0, @prev_vote := NULL) AS vars
    ORDER BY VoteCount DESC, CreationDate DESC
)
SELECT rp.PostId,
       rp.Title,
       rp.OwnerDisplayName,
       rp.CreationDate,
       rp.LastEdited,
       rp.CommentCount,
       rp.VoteCount,
       CASE 
           WHEN rp.VoteCount > 10 THEN 'Popular'
           WHEN rp.CommentCount > 5 THEN 'Engaging'
           ELSE 'Average'
       END AS PostCategory,
       pd.TagNames
FROM RankedPosts rp
JOIN PostDetails pd ON rp.PostId = pd.PostId
ORDER BY rp.Rank;
