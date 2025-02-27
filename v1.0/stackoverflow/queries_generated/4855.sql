WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Filtering only questions
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
), PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalUpvotes,
    us.TotalDownvotes,
    us.TotalBadges,
    us.TotalComments,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViews,
    rp.AnswerCount AS QuestionAnswers,
    phi.EditCount AS NumberOfEdits,
    phi.LastEditDate,
    phi.EditTypes
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    PostHistoryInfo phi ON rp.PostId = phi.PostId
WHERE 
    us.TotalUpvotes > 10 -- Only users with more than 10 upvotes
    AND rp.PostRank = 1 -- Only the most recent question per user
ORDER BY 
    us.TotalUpvotes DESC, 
    rp.Score DESC;
