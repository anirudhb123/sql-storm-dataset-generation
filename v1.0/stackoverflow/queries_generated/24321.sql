WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
TweetActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(*) AS Tweets
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.Body LIKE '%tweet%'
    GROUP BY 
        U.Id
),
ActivitySummary AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.UpVotes,
        UA.DownVotes,
        UA.ClosedPosts,
        UA.TotalPosts,
        UA.Questions,
        UA.Answers,
        COALESCE(TA.Tweets, 0) AS Tweets
    FROM 
        UserActivity UA
    LEFT JOIN 
        TweetActivity TA ON UA.UserId = TA.UserId
)
SELECT 
    AS.UserId,
    AS.DisplayName,
    AS.UpVotes,
    AS.DownVotes,
    AS.ClosedPosts,
    AS.TotalPosts,
    AS.Questions,
    AS.Answers,
    CASE 
        WHEN AS.Tweets > 0 THEN AS.Tweets 
        ELSE NULL 
    END AS ActiveTweets,
    CASE 
        WHEN AS.Tweets BETWEEN 5 AND 10 THEN 'Moderate Tweet Activity' 
        WHEN AS.Tweets > 10 THEN 'High Tweet Activity' 
        ELSE 'Low or No Tweet Activity' 
    END AS TweetActivityLevel
FROM 
    ActivitySummary AS
WHERE 
    AS.TotalPosts > 0 
    AND (AS.UpVotes - AS.DownVotes) > 0
ORDER BY 
    AS.UpVotes DESC,
    AS.TotalPosts DESC
LIMIT 50;
