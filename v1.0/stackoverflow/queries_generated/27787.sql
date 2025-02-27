WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Reputation ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerName,
        CommentCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        UserRank <= 10  -- Top 10 posts per reputation category
), PostAnalysis AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.ViewCount,
        fp.Score,
        fp.OwnerName,
        fp.CommentCount,
        COUNT(DISTINCT bha.Id) AS BadgeCount  -- Count of badges earned by the post author
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges bha ON bha.UserId = (SELECT Id FROM Users WHERE DisplayName = fp.OwnerName)
    GROUP BY 
        fp.PostId, fp.Title, fp.ViewCount, fp.Score, fp.OwnerName, fp.CommentCount
), FinalOutput AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.ViewCount,
        pa.Score,
        pa.OwnerName,
        pa.CommentCount,
        pa.BadgeCount,
        CASE 
            WHEN pa.BadgeCount > 5 THEN 'Highly Recognized'
            WHEN pa.BadgeCount BETWEEN 1 AND 5 THEN 'Moderately Recognized'
            ELSE 'Not Recognized'
        END AS RecognitionLevel
    FROM 
        PostAnalysis pa
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    OwnerName,
    CommentCount,
    BadgeCount,
    RecognitionLevel
FROM 
    FinalOutput
ORDER BY 
    ViewCount DESC, Score DESC;

This SQL query analyzes and ranks posts based on user reputation while counting comments and badges earned by post authors. It filters for the top posts per reputation category, categorizes recognition based on badge count, and finally presents a sorted view with key metrics.
