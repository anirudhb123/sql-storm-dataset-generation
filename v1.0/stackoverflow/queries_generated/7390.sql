WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(COUNT(a.Id), 0) AS AnswerCount,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS DownVotes,
        RANK() OVER (ORDER BY COALESCE(SUM(vt.VoteTypeId = 2), 0) - COALESCE(SUM(vt.VoteTypeId = 3), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    WHERE 
        p.PostTypeId = 1 -- Filter for questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        ra.CommentCount,
        ra.LastCommentDate,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.AnswerCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CommentCount,
    pd.LastCommentDate,
    pd.Rank
FROM 
    PostDetails pd
WHERE 
    pd.Rank <= 10 -- Get top 10 ranked questions
ORDER BY 
    pd.Rank;
