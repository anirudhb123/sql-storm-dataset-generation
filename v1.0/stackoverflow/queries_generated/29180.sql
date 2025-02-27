WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_id ON tag_id IS NOT NULL
    LEFT JOIN 
        Tags t ON tag_id::int = t.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.AnswerCount,
        r.CommentCount,
        r.Tags,
        r.Rank
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Tags,
    u.DisplayName AS EngagingUser,
    ue.CommentCount AS EngagingUserComments,
    ue.VoteCount AS EngagingUserVotes,
    ue.BadgeCount AS EngagingUserBadges
FROM 
    TopPosts tp
LEFT JOIN 
    UserEngagement ue ON ue.UserId IN (
        SELECT DISTINCT c.UserId 
        FROM Comments c 
        WHERE c.PostId = tp.PostId
    )
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate DESC;
