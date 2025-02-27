
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1  
    GROUP BY Tag
),
TopTags AS (
    SELECT Tag
    FROM TagCounts
    ORDER BY PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  
    AND EXISTS (SELECT 1 FROM TagCounts tc WHERE tc.Tag IN (SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)))
    GROUP BY p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.OwnerName,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        COALESCE(pd.UpVotes / NULLIF(pd.DownVotes, 0), 0) AS UpvoteDownvoteRatio
    FROM PostDetails pd
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.OwnerName,
    fr.CommentCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.UpvoteDownvoteRatio
FROM FinalResults fr
WHERE fr.OwnerName IS NOT NULL
ORDER BY fr.UpvoteDownvoteRatio DESC, fr.ViewCount DESC
LIMIT 20;
