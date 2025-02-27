WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        U.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 -- Only retrieve questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Only consider the last year
), 
TopRankedPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per tag
), 
PostViews AS (
    SELECT 
        Tags,
        COUNT(ViewCount) AS TotalViews,
        AVG(Score) AS AverageScore
    FROM 
        TopRankedPosts
    GROUP BY 
        Tags
),
MostViewed AS (
    SELECT 
        Tags,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        PostViews
), 
UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    m.Tags,
    m.TotalViews,
    m.AverageScore,
    b.UserId,
    b.BadgeCount
FROM 
    MostViewed m
JOIN 
    TopRankedPosts tp ON tp.Tags = m.Tags
JOIN 
    UserBadgeCount b ON tp.OwnerUserId = b.UserId
WHERE 
    m.ViewRank = 1 -- Get the most viewed posts
ORDER BY 
    m.TotalViews DESC;
