WITH ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        unnest(string_to_array(trim(both '<>' FROM p.Tags), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Consider only questions
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount,
        MIN(CreationDate) AS FirstUsed,
        MAX(CreationDate) AS LastUsed
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only count users that have asked questions
    GROUP BY 
        u.Id
),
BadgesSummary AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ut.UserId,
    ut.DisplayName,
    ut.Reputation,
    ut.QuestionsAsked,
    ut.TotalAnswers,
    ut.TotalUpVotes,
    ut.TotalDownVotes,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    ts.Tag,
    ts.TagCount,
    ts.FirstUsed,
    ts.LastUsed
FROM 
    UserStats ut
LEFT JOIN 
    BadgesSummary bs ON ut.UserId = bs.UserId
LEFT JOIN 
    TagStats ts ON ts.Tag IN (
        SELECT 
            Tag 
        FROM 
            ProcessedTags 
        WHERE 
            ProcessedTags.PostId IN (
                SELECT 
                    p.Id 
                FROM 
                    Posts p 
                WHERE 
                    p.OwnerUserId = ut.UserId
            )
    )
ORDER BY 
    ut.Reputation DESC, 
    ts.TagCount DESC;
