WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes, -- Count of Upvotes
        SUM(v.VoteTypeId = 3) AS DownVotes -- Count of Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Tags
),
TaggedPosts AS (
    SELECT 
        rp.*, 
        (SELECT STRING_AGG(t.TagName, ', ') 
         FROM Tags t 
         WHERE t.Id = ANY(string_to_array(rp.Tags, '><')::int[])) AS FormattedTags
    FROM 
        RankedPosts rp
),
FinalOutput AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.Body, 
        tp.CreationDate, 
        tp.Author, 
        tp.CommentCount, 
        tp.UpVotes, 
        tp.DownVotes, 
        tp.FormattedTags,
        CASE 
            WHEN tp.UpVotes - tp.DownVotes >= 10 THEN 'Highly Active'
            WHEN tp.UpVotes - tp.DownVotes BETWEEN 1 AND 9 THEN 'Moderately Active'
            ELSE 'Less Active'
        END AS ActivityLevel
    FROM 
        TaggedPosts tp
    ORDER BY 
        tp.UpVotes - tp.DownVotes DESC
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    CreationDate >= NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
LIMIT 50; -- Display top 50 posts

