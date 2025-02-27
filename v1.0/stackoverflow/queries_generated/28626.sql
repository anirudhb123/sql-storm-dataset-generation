WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Body
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId 
        AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, or Tags
    WHERE 
        rp.rn = 1 -- Keep only the top-ranked post based on CreationDate
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CommentCount, rp.AnswerCount, rp.UpVotes, rp.DownVotes, ph.UserDisplayName, ph.CreationDate
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CommentCount,
        pd.AnswerCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.LastEditor,
        pd.LastEditDate,
        pd.EditHistoryCount,
        RANK() OVER (ORDER BY pd.CommentCount DESC, pd.AnswerCount DESC, pd.UpVotes DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.LastEditor,
    tp.LastEditDate,
    tp.EditHistoryCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10 -- Get top 10 posts based on ranking criteria
ORDER BY 
    tp.Rank;
