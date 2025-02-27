WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id OR t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        PostId, Title, Body, CreationDate, Score, ViewCount, AnswerCount, CommentCount, Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.PostsCreated,
    ua.UpVotesReceived,
    ua.DownVotesReceived,
    ua.BadgesEarned,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Tags
FROM 
    UserActivity ua
JOIN 
    TopPosts tp ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
ORDER BY 
    ua.UpVotesReceived DESC, tp.Score DESC;
