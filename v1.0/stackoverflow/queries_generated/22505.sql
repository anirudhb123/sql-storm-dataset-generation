WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((
            SELECT json_agg(vote) 
            FROM (
                SELECT 
                    vt.Name AS VoteType, 
                    COUNT(*) AS VoteCount 
                FROM Votes v 
                JOIN VoteTypes vt ON v.VoteTypeId = vt.Id 
                WHERE v.PostId = p.Id 
                GROUP BY vt.Name
            ) AS vote
        ), '[]') AS VoteDistribution,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.VoteDistribution,
        Tags.TagName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        STRING_AGG(DISTINCT CASE WHEN bp.UserId IS NOT NULL THEN u.DisplayName END, ', ') AS BadgerUsers
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(Tags, 2, length(Tags)-2), '><')::int[])  -- parsing tags
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId
    LEFT JOIN 
        Users u ON b.UserId = u.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.VoteDistribution, Tags.TagName
),
RankedPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.VoteDistribution,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    rp.TagName,
    rp.ViewRank,
    CASE 
        WHEN rp.ViewRank <= 5 THEN 'Top Performer' 
        ELSE 'Potential Improvement' 
    END AS PerformanceCategory,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM Votes v 
            WHERE v.PostId = rp.PostId 
              AND v.VoteTypeId IN (2, 3) -- upvotes and downvotes
        ) THEN 'Feedback Present'
        ELSE 'No Feedback'
    END AS FeedbackStatus
FROM 
    RankedPosts rp
WHERE 
    rp.OwnerPostRank = 1     -- Only retrieving most recent post per owner
ORDER BY 
    rp.ViewRank, rp.CreationDate DESC;
