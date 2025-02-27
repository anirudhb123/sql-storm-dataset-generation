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
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
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
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Title IS NOT NULL
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
),
TagCount AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        PostDetails
    GROUP BY 
        TagName
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
    TopTags tt ON pd.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    pd.PostType NOT IN ('Wiki', 'TagWiki', 'ModeratorNomination')
    AND tt.Rank IS NOT NULL
ORDER BY 
    pd.CreationDate DESC, 
    tt.PostCount DESC
LIMIT 100;
