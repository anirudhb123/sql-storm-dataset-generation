WITH TagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(ans.Id) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COALESCE(SUM(vt.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(vt.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(DISTINCT u.Id) AS UniqueVoters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ans ON p.Id = ans.ParentId
    LEFT JOIN 
        PostLinks pl ON pl.PostId = p.Id
    LEFT JOIN 
        Tags t ON pl.RelatedPostId = t.WikiPostId OR pl.RelatedPostId = t.ExcerptPostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ts.PostId,
    ts.Title,
    ts.Tags,
    ts.CommentCount,
    ts.AnswerCount,
    ts.TotalBounty,
    ts.UpVotes,
    ts.DownVotes,
    ts.UniqueVoters,
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TagStats ts
JOIN 
    Users u ON ts.UniqueVoters = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    ts.TotalBounty DESC, ts.AnswerCount DESC, ts.CommentCount DESC;
