WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1  -- Only questions
),
PostVoteCount AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
MergedResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCount pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        UserBadges ub ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
    WHERE 
        rp.ViewRank <= 5  -- Top 5 by view count for each user
)
SELECT 
    mr.PostId,
    mr.Title,
    mr.ViewCount,
    mr.UpVotes,
    mr.DownVotes,
    mr.BadgeCount,
    CASE 
        WHEN mr.BadgeCount IS NULL THEN 'No Badges'
        WHEN mr.BadgeCount > 5 THEN 'Experienced User'
        ELSE 'Novice User'
    END AS UserExperience,
    DATE_TRUNC('month', mr.CreationDate) AS MonthCreated,
    COUNT(DISTINCT mr.PostId) OVER () AS TotalPostsLastYear,
    LEAD(mr.ViewCount) OVER (ORDER BY mr.ViewCount DESC) AS NextPostViewCount,
    LAG(mr.UpVotes) OVER (ORDER BY mr.ViewCount DESC) AS PreviousUpVotes
FROM 
    MergedResults mr
WHERE 
    mr.BadgeCount IS NOT NULL OR mr.UpVotes > 10 
ORDER BY 
    mr.ViewCount DESC NULLS LAST;
