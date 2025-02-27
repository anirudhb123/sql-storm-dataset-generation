WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_array)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostsWithAverageScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount,
        rp.Tags,
        COALESCE(AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL), 0) AS AverageBounty
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    GROUP BY 
        rp.PostId
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    OwnerDisplayName,
    AnswerCount,
    UpVotes,
    DownVotes,
    CommentCount,
    Tags,
    AverageBounty,
    CASE
        WHEN UpVotes - DownVotes > 10 THEN 'Hot Topic'
        WHEN AnswerCount > 5 THEN 'Popular Question'
        ELSE 'Standard'
    END AS PostCategory
FROM 
    PostsWithAverageScores
ORDER BY 
    UpVotes DESC, CreationDate DESC
LIMIT 10;
