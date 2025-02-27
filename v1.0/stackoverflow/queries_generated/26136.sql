WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ARRAY_AGG(DISTINCT TRIM(UNNEST(string_to_array(p.Tags, '>'))) ) AS Tags
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.OwnerDisplayName,
        rp.CommentCount, rp.UpVotes, rp.DownVotes
),
FinalOutput AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        CASE 
            WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
            WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        COALESCE(TAGGEDPOSTS.Tags, ARRAY[]::varchar[]) AS Tags
    FROM 
        TaggedPosts tp
)
SELECT 
    *,
    'https://stackoverflow.com/questions/' || PostId AS PostUrl
FROM 
    FinalOutput
ORDER BY 
    CreationDate DESC
LIMIT 10;
