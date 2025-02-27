
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS TagCount,
        p.CreationDate,
        p.LastActivityDate,
        u.Reputation,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS UserPostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_number := 0, @current_user := NULL) AS vars
    WHERE 
        p.PostTypeId = 1  
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.Reputation > 1000 THEN 'Experienced'
            WHEN rp.Reputation BETWEEN 100 AND 1000 THEN 'Moderate'
            ELSE 'Novice'
        END AS UserExperience
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagCount > 3  
),
PostInsights AS (
    SELECT 
        p.PostId,
        p.Title,
        p.UserExperience,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        FilteredPosts p
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId, p.Title, p.UserExperience
),
RecentInsights AS (
    SELECT 
        PostId,
        Title,
        UserExperience,
        CommentCount,
        LastVoteDate,
        @recent_rank := @recent_rank + 1 AS RecentRank
    FROM 
        PostInsights
    CROSS JOIN (SELECT @recent_rank := 0) AS vars
    ORDER BY 
        LastVoteDate DESC
)
SELECT 
    ri.PostId,
    ri.Title,
    ri.UserExperience,
    ri.CommentCount,
    ri.LastVoteDate
FROM 
    RecentInsights ri
WHERE 
    ri.RecentRank <= 10  
ORDER BY 
    ri.LastVoteDate DESC;
