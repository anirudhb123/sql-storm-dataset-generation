WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags FROM '\#\[(.*?)\]') ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Taking top 5 posts per tag
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Tags,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        array_agg(DISTINCT b.Name) AS BadgesAwarded
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        tp.PostId, u.DisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Tags,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerName,
    pd.BadgesAwarded,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2) AS UpVotesCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = pd.PostId AND v.VoteTypeId = 3) AS DownVotesCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, 
    pd.CreationDate DESC;
