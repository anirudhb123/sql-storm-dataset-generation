WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.Score IS NOT NULL
        AND p.ViewCount IS NOT NULL
), TopRankedQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        t.TagName,
        t.Id AS TagId
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON t.TagName = ANY (string_to_array(rp.Tags, '>'))
    WHERE 
        rp.TagRank <= 3
), UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
), QuestionsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        SUM(CASE WHEN v.CreationDate > NOW() - INTERVAL '30 days' THEN 1 ELSE 0 END) AS RecentVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
), PostHistoryInfo AS (
    SELECT
        ph.PostId,
        ph.PostHistoryTypeId,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) -- Edit Title or Body
    GROUP BY 
        ph.PostId
)

SELECT 
    rq.PostId,
    rq.Title,
    rq.CreationDate,
    rq.Score,
    rq.ViewCount,
    rq.TagId,
    rq.TagName,
    ub.UserId,
    ub.DisplayName,
    ub.BadgeCount,
    qwv.Upvotes,
    qwv.Downvotes,
    qwv.RecentVotes,
    phi.LastEditedDate,
    phi.EditComments
FROM 
    TopRankedQuestions rq
LEFT JOIN 
    UsersWithBadges ub ON rq.PostId = (SELECT AcceptedAnswerId FROM Posts WHERE Id = rq.PostId)
LEFT JOIN 
    QuestionsWithVotes qwv ON rq.PostId = qwv.PostId
LEFT JOIN 
    PostHistoryInfo phi ON rq.PostId = phi.PostId
WHERE 
    phi.LastEditedDate IS NOT NULL
ORDER BY 
    rq.Score DESC, rq.ViewCount DESC;

This SQL query forms a comprehensive analytical report based on the Stack Overflow schema described. It utilizes a mix of CTEs for structure, joins, aggregate functions, window functions, and applicable predicates, making it a robust benchmark for performance testing.
