
WITH RecursiveTagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        (@row_number := @row_number + 1) AS Rank
    FROM 
        RecursiveTagCounts, (SELECT @row_number := 0) AS r
    WHERE 
        TagCount > 10 
    ORDER BY 
        TagCount DESC
),
MostVotedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
),
TopVotedQuestions AS (
    SELECT 
        QuestionId, 
        Title, 
        UpVotes, 
        DownVotes,
        (@vote_rank := @vote_rank + 1) AS VoteRank
    FROM 
        MostVotedQuestions, (SELECT @vote_rank := 0) AS r
    WHERE 
        UpVotes > 5 
    ORDER BY 
        UpVotes DESC
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
EnhanceQueries AS (
    SELECT 
        tt.TagName,
        tt.TagCount,
        tq.QuestionId,
        tq.Title,
        tq.UpVotes,
        tq.DownVotes,
        ub.BadgeCount, 
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        TopTags tt
    JOIN 
        TopVotedQuestions tq ON tq.Title LIKE CONCAT('%', tt.TagName, '%')
    JOIN 
        Users u ON u.Id = tq.QuestionId
    JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)
SELECT 
    TagName,
    COUNT(DISTINCT QuestionId) AS RelatedQuestions,
    AVG(UpVotes) AS AvgUpVotes,
    AVG(DownVotes) AS AvgDownVotes,
    SUM(GoldBadges) AS TotalGoldBadges, 
    SUM(SilverBadges) AS TotalSilverBadges, 
    SUM(BronzeBadges) AS TotalBronzeBadges
FROM 
    EnhanceQueries
GROUP BY 
    TagName
ORDER BY 
    RelatedQuestions DESC, AvgUpVotes DESC;
