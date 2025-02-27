WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostCommentSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        pvs.UpVotes,
        pvs.DownVotes,
        pcs.TotalComments,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        PostCommentSummary pcs ON rp.PostId = pcs.PostId
    LEFT JOIN 
        UsersWithBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.rn = 1 -- Only the most recent question per user
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    COALESCE(tq.UpVotes, 0) - COALESCE(tq.DownVotes, 0) AS NetVotes,
    tq.BadgeCount,
    CASE 
        WHEN tq.BadgeCount > 0 THEN 'Has Badge'
        ELSE 'No Badge'
    END AS BadgeStatus
FROM 
    TopQuestions tq
ORDER BY 
    NetVotes DESC, tq.CreationDate DESC;
