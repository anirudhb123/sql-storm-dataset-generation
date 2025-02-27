WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT v.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Owner, CommentCount, AnswerCount, UpVotes, DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Owner,
    t.CommentCount,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes,
    pht.Name AS PostHistoryType
FROM 
    TopPosts t
LEFT JOIN 
    PostHistory ph ON t.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY 
    t.UpVotes DESC, t.CreationDate DESC;
