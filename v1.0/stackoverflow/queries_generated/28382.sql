WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags, 
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS DownVotes,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        Tags, 
        OwnerDisplayName,
        AnswerCount,
        UpVotes,
        DownVotes,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.AnswerCount,
    tp.UpVotes - tp.DownVotes AS Score,
    STRING_AGG(t.TagName, ', ') AS TagList
FROM 
    TopPosts tp
LEFT JOIN 
    Tags t ON t.TagName = ANY(string_to_array(tp.Tags, '><'))
GROUP BY 
    tp.OwnerDisplayName, tp.Title, tp.Body, tp.CreationDate, tp.AnswerCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    Score DESC;
