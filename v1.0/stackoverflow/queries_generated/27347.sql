WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS RankInTag,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag(tagName) ON TRUE
    JOIN 
        Tags t ON tag.tagName = t.TagName
    WHERE 
        p.PostTypeId IN (1, 2) -- only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags 
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankInTag <= 5 -- Top 5 posts per tag
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Tags,
    ue.DisplayName AS EngagedUser,
    ue.VoteCount,
    ue.CommentCount AS UserCommentCount,
    ue.BadgeCount
FROM 
    TopPosts tp
JOIN 
    UserEngagement ue ON ue.VoteCount > 0 OR ue.CommentCount > 0
ORDER BY 
    tp.Score DESC, ue.VoteCount DESC
LIMIT 50;
