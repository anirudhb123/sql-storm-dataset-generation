WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        STRING_AGG(t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) DESC, COUNT(DISTINCT c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CommentCount,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Top 10 posts
)
SELECT 
    tp.*,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'Positive'
        WHEN tp.UpVotes < tp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT 
        STRING_AGG(DisplayName, ', ') 
     FROM 
        Users u 
     JOIN 
        Votes v ON v.PostId = tp.PostId AND v.VoteTypeId = 2
    ) AS TopVoterNames
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC;
