WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS TotalBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(T.Tags, '<>')) AS Tag,
        COUNT(P.Id) AS TagCount
    FROM 
        Posts P
    JOIN 
        Tags T ON T.Id = ANY(string_to_array(P.Tags, '<>')::int[])
    GROUP BY 
        T.Tags
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.TotalPosts,
        UPS.Questions,
        UPS.Answers,
        COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        UserPostStats UPS
    LEFT JOIN 
        UserBadgeCounts UBC ON UPS.UserId = UBC.UserId
    LEFT JOIN 
        Votes V ON UPS.UserId = V.UserId
    GROUP BY 
        UPS.UserId, UPS.DisplayName, UPS.TotalPosts, UPS.Questions, UPS.Answers, UBC.TotalBadges
)
SELECT 
    UEG.DisplayName,
    UEG.TotalPosts,
    UEG.Questions,
    UEG.Answers,
    UEG.TotalBadges,
    UEG.UpVotes,
    UEG.DownVotes,
    PT.Tag,
    PT.TagCount
FROM 
    UserEngagement UEG
CROSS JOIN 
    PopularTags PT
ORDER BY 
    UEG.TotalPosts DESC, UEG.UpVotes DESC;
