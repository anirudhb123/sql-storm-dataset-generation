WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(ROUND(AVG(voteCount), 2), 0) AS AverageVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS voteCount FROM Votes GROUP BY PostId) v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- 1 = Question
    GROUP BY 
        p.Id, u.DisplayName
), TagAnalysis AS (
    SELECT 
        UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
), UserBenchmark AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT pa.Id) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Posts pa ON pa.ParentId = p.Id AND pa.PostTypeId = 2
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.AverageVotes,
    ua.UserId,
    ua.DisplayName AS UserDisplayName,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ta.Tag,
    ta.TagCount
FROM 
    RankedPosts rp
JOIN 
    UserBenchmark ua ON rp.OwnerUserId = ua.UserId
JOIN 
    TagAnalysis ta ON ta.Tag = ANY(string_to_array(rp.Tags, '><'))
WHERE 
    rp.AnswerCount > 5 AND rp.AverageVotes > 2
ORDER BY 
    rp.CreationDate DESC, rp.AverageVotes DESC;
