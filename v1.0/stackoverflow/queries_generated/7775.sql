WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        COALESCE(b.Badges, 0) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS Badges 
        FROM Badges 
        GROUP BY UserId
    ) b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
        AND p.Score > 5
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS TagCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(pt.PostId) DESC) AS TagRank
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question' 
    GROUP BY 
        t.TagName
),
TopAuthors AS (
    SELECT 
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS AuthorRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Author,
    rp.BadgeCount,
    pt.TagName AS PopularTag,
    ta.DisplayName AS TopAuthor,
    ta.PostsCount AS TopAuthorPostsCount,
    ta.TotalScore AS TopAuthorTotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagRank <= 5
LEFT JOIN 
    TopAuthors ta ON ta.AuthorRank <= 10
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate DESC;
