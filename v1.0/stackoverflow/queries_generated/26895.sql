WITH RecursiveTagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        TagName
), TagStatistics AS (
    SELECT 
        TagName, 
        PostCount, 
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        RecursiveTagCounts
),
MostPopularTags AS (
    SELECT 
        TagName, 
        PostCount
    FROM 
        TagStatistics
    WHERE 
        Rank <= 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount, 
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u 
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
        LEFT JOIN Votes v ON p.Id = v.PostId 
        LEFT JOIN Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
TagPopularityMetrics AS (
    SELECT 
        mpt.TagName,
        COALESCE(ue.UserId, -1) AS UserId,
        COALESCE(ue.DisplayName, 'No User') AS UserName,
        ue.QuestionCount AS UserQuestionCount,
        ue.UpVotes AS UserUpVotes,
        ue.DownVotes AS UserDownVotes,
        ue.GoldBadges AS UserGoldBadges,
        ue.SilverBadges AS UserSilverBadges,
        ue.BronzeBadges AS UserBronzeBadges
    FROM 
        MostPopularTags mpt
        LEFT JOIN UserEngagement ue ON ue.QuestionCount > 0
)
SELECT 
    t.TagName,
    t.UserName,
    t.UserQuestionCount,
    t.UserUpVotes,
    t.UserDownVotes,
    t.UserGoldBadges,
    t.UserSilverBadges,
    t.UserBronzeBadges
FROM 
    TagPopularityMetrics t
ORDER BY
    t.TagName, t.UserQuestionCount DESC;
