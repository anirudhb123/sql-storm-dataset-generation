
WITH TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM Posts,
        STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS value
    WHERE PostTypeId = 1  
    GROUP BY value
),
TopTags AS (
    SELECT TOP 10 Tag
    FROM TagCounts
    ORDER BY PostCount DESC
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  
    AND EXISTS (
        SELECT 1 FROM TagCounts tc 
        WHERE tc.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
    )
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
        COALESCE(CAST(pd.UpVotes AS FLOAT) / NULLIF(pd.DownVotes, 0), 0) AS UpvoteDownvoteRatio
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
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
