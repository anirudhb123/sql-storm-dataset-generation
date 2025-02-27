
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount,
        pt.Name AS PostType
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND p.Title IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.CreationDate, pt.Name, p.Tags, p.AcceptedAnswerId
),
TagCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        PostDetails
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM 
        TagCount, (SELECT @rank := 0) r
    ORDER BY 
        PostCount DESC
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.AuthorName,
    pd.CreationDate,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    pd.AcceptedAnswerId,
    tt.TagName,
    tt.PostCount
FROM 
    PostDetails pd
LEFT JOIN 
    TopTags tt ON pd.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    pd.PostType NOT IN ('Wiki', 'TagWiki', 'ModeratorNomination')
    AND tt.Rank IS NOT NULL
ORDER BY 
    pd.CreationDate DESC, 
    tt.PostCount DESC
LIMIT 100;
