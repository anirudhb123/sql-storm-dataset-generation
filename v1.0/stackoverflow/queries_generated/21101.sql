WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

AggregatedUserData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.Reputation) AS TotalReputation,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts,
        MAX(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        PostLinks pl ON rp.PostId = pl.PostId
    GROUP BY 
        rp.PostId
)

SELECT 
    R.*,
    U.TotalReputation,
    U.BadgeCount,
    P.CommentCount,
    P.RelatedPosts,
    P.HasAcceptedAnswer,
    CASE 
        WHEN U.LastPostDate IS NULL THEN 'No Posts' 
        ELSE 'Active User' 
    END AS UserStatus,
    CASE 
        WHEN R.ViewCount > 1000 THEN 'Hot Post'
        WHEN R.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Post'
        ELSE 'Cold Post'
    END AS PostHeat
FROM 
    RankedPosts R
LEFT JOIN 
    AggregatedUserData U ON R.PostId = (SELECT p.AcceptedAnswerId FROM Posts p WHERE p.Id = R.PostId)
LEFT JOIN 
    PostStatistics P ON R.PostId = P.PostId
WHERE 
    R.Rank <= 5
ORDER BY 
    R.PostTypeId, R.Score DESC, R.CreationDate DESC;
