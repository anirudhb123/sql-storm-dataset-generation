
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
        AND p.Title IS NOT NULL
    GROUP BY 
        p.Id, u.DisplayName, p.CreationDate, pt.Name, p.Tags, p.AcceptedAnswerId
),
TagCount AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        PostDetails
    CROSS APPLY STRING_SPLIT(Tags, ',') 
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
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
    TopTags tt ON pd.Tags LIKE '%' + tt.TagName + '%'
WHERE 
    pd.PostType NOT IN ('Wiki', 'TagWiki', 'ModeratorNomination')
    AND tt.Rank IS NOT NULL
ORDER BY 
    pd.CreationDate DESC, 
    tt.PostCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
