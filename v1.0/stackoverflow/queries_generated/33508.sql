WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AnswerCount,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT 
        a.Id,
        a.Title,
        a.OwnerUserId,
        a.AnswerCount,
        a.CreationDate,
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostCTE q ON a.ParentId = q.Id  -- Joining to find answers
    WHERE 
        a.PostTypeId = 2  -- Only Answers
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.AnswerCount,
    ub.DisplayName,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    pvs.VoteCount,
    pvs.UpVotes,
    pvs.DownVotes,
    rp.CreationDate
FROM 
    RecursivePostCTE rp
INNER JOIN 
    Users u ON rp.OwnerUserId = u.Id
INNER JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    PostVoteSummary pvs ON rp.Id = pvs.PostId
WHERE 
    rp.Level = 1  -- Focusing only on top-level questions
    AND ub.BadgeCount > 0  -- Only users with at least one badge
ORDER BY 
    rp.AnswerCount DESC, 
    ub.BadgeCount DESC;
