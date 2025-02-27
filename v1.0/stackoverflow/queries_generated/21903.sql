WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        MAX(COALESCE(ph.CreationDate, NULL)) AS LastHistoryDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        pd.*,
        us.DisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges
    FROM 
        PostDetails pd
    JOIN 
        UserStats us ON pd.OwnerUserId = us.UserId
    WHERE 
        pd.PostRank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.LastActivityDate,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.GoldBadges,
    tp.SilverBadges,
    tp.BronzeBadges,
    CASE 
        WHEN tp.LastActivityDate IS NOT NULL THEN 
            'Active' 
        ELSE 
            'Inactive' 
    END AS PostStatus,
    CASE 
        WHEN tp.CommentCount IS NULL THEN 'No comments'
        ELSE 'Has comments'
    END AS CommentStatus,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypesUsed
FROM 
    TopPosts tp
LEFT JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.LastActivityDate, 
    tp.CommentCount, tp.UpVotes, tp.DownVotes, 
    tp.GoldBadges, tp.SilverBadges, tp.BronzeBadges
ORDER BY 
    tp.UpVotes DESC, tp.LastActivityDate DESC;
