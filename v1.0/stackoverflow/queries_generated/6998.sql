WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Author,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByTags <= 5
)
SELECT 
    fp.Title,
    fp.Author,
    fp.CreationDate,
    fp.AnswerCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    COALESCE((SELECT STRING_AGG(Tags.TagName, ', ') 
               FROM Tags 
               WHERE Tags.Id IN (SELECT UNNEST(string_to_array(fp.Tags, ', '))::int)), 'N/A') AS RelatedTags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC, 
    fp.UpVotes DESC
LIMIT 50;
