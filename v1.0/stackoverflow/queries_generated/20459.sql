WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount,
        CASE 
            WHEN UPPER(p.Title) LIKE '%SQL%' THEN 'Interest in SQL'
            ELSE 'General'
        END AS InterestCategory,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag::int = t.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.PostTypeId,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.ScoreRank,
        rp.UpvoteCount,
        rp.DownvoteCount,
        rp.InterestCategory,
        rp.TagsList,
        CASE 
            WHEN rp.Score >= 10 THEN 'Highly Engaging'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 
        AND rp.ScoreRank <= 5 
        AND rp.InterestCategory = 'Interest in SQL'
),
FinalResults AS (
    SELECT 
        f.*,
        COALESCE(b.Name, 'No badges') AS BadgeName,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        FilteredPosts f
    LEFT JOIN 
        Badges b ON f.OwnerUserId = b.UserId AND b.Date = (
            SELECT MAX(b2.Date)
            FROM Badges b2
            WHERE b2.UserId = f.OwnerUserId
        )
)
SELECT 
    *,
    (CASE 
        WHEN BadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN BadgeClass = 2 THEN 'Silver Badge Holder'
        WHEN BadgeClass = 3 THEN 'Bronze Badge Holder'
        ELSE 'No Badge Holder'
    END) AS BadgeStatus
FROM 
    FinalResults
ORDER BY 
    EngagementLevel DESC, Score DESC;
